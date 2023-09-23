import os
import json
import ast
import time
from datetime import datetime
import tornado.httpserver
import tornado.options
import tornado.ioloop
import tornado.web
import tornado.wsgi
import motor.motor_tornado
import googlemaps
from bson import ObjectId
from dotenv import load_dotenv
from tornado import gen, web

#imports for victor
import numpy as np
import time

load_dotenv()
client = motor.motor_tornado.MotorClient(os.environ["COSMOS_CONNECTION_STRING"])
db = client.get_database('primary')
gmaps = googlemaps.Client(key=os.environ["GOOGLE_MAPS_API_KEY"])

tornado.options.define('port', default='8000', help='REST API Port', type=int)

class BaseHandler(tornado.web.RequestHandler):
    """
    Base handler gonna to be used instead of RequestHandler
    """

    def write_error(self, status_code, **kwargs):
        if status_code in [403, 404, 500, 503]:
            self.write('Error %s' % status_code)
        else:
            self.write('BOOM!')


class ErrorHandler(tornado.web.ErrorHandler, BaseHandler):
    """
    Default handler gonna to be used in case of 404 error
    """
    pass


class StatusHandler(BaseHandler):
    """
    GET handler to check the status on the web service
    """

    def get(self):
        self.set_status(200)
        self.finish({'status': 'Rest API Service status is ok...'})

class MainHandler(BaseHandler):
    """
    GET handler for main page, loads the index.html
    """

    def get(self):
        self.set_status(200)
        self.write({'data1' : ['location1','location2']})

class PostHandler(BaseHandler):
    async def post(self):
        report = {}
        report["_id"] = str(ObjectId())
        report["item_type"] = "masks"
        report["timestamp"] = int(time.time())
        new_report = await self.settings["db"]["reports"].insert_one(report)
        created_report = await self.settings["db"]["reports"].find_one(
            {"_id": new_report.inserted_id}
        )
        self.set_status(201)
        return self.write(created_report)

class SubmitHandler(BaseHandler):
    """
    POST handler submitting a report on item and quantity
    """
    async def post(self):
        self.set_status(200)
        data = tornado.escape.json_decode(self.request.body)
        place = await self.settings["db"]["locations"].find_one(
            filter={
                '_id': data["place_id"],
            }
        )
        place["stock"][data["item"]] = (data["qty"], int(time.time()))
        await self.settings["db"]["locations"].replace_one(
            {'_id': place['_id']},
            place
        )
        self.write(data)
        self.write([{'name': 'narcan', 'id': 0}, {'name': 'mask', 'id': 1}])

class RouteHandler(BaseHandler):
    """
    POST handler for getting the best route
    """
    async def post(self):
        self.set_status(200)
        data = tornado.escape.json_decode(self.request.body) #get info from front-end

        gmap = self.settings["gmaps"]
        value = gmap.places_nearby(location=(data["location"]), keyword='drugstore|pharmacy', rank_by='distance') #location around user location
        
        for result in value: #put locations into db if not already there
            self.settings["db"]["locations"].update_one(
                filter={
                    '_id': result["place_id"],
                },
                update={
                    '$setOnInsert': {
                        'latlong': (result["geometry"]["location"]["lat"], result["geometry"]["location"]["lng"]),
                        'stock': {},
                        'name': result["name"],
                        'vicinity': result['vicinity'],
                    },
                },
                upsert=True,
            )

        #get locations nearby, their times, stock
        locationsDict = {}
        for result in value:
            # Query the database to find the location
            db_location = self.settings["db"]["locations"].find_one({'_id': result["place_id"]})

            if db_location:
                # Extract the required information and store it in the dictionary
                locationsDict[result["place_id"]] = {
                    'location': db_location['latlong'],
                    'stock': [db_location['stock'], db_location['timestamp']]
                }

        #CALL THIS FOR ALGO
        #itemTypes is list of strings we want
        itemTypes = data["item"] #need to extend to multiple

        currentTime = time.time

        startingLocation = data["location"]
        minDistGradDescent(itemTypes, currentTime, locationsDict, startingLocation)
        

        #VICTORS HELPER FUNCTIONS
        def calcProb(currentTime, listOfNumAndTime, averageNum):
            daysPassed = round((currentTime - listOfNumAndTime[1])/(24 * 60 * 60))

            if listOfNumAndTime[0] == 0:
                return min(daysPassed/14, .5)

            if daysPassed == 0:
                return 1

            return min(1, max(0,(1 - daysPassed/listOfNumAndTime[0]))  +  min(daysPassed/14, .5) )


        def individualFilter(itemType, currentTime, oneLocDict, averageNum):
            filteredInnerDict = {'latlong': oneLocDict['latlong'],
                        'prob': calcProb(currentTime, oneLocDict['stock'][itemType], averageNum)
                        }
            return filteredInnerDict


        def preProccessFilterAndComputeProbs(itemType, currentTime, locationsDict):
            averageNum = 0
            for locid in locationsDict:
                averageNum += locationsDict[locid]['stock'][itemType][0]
            averageNum = averageNum/len(locationsDict.keys())

            newFilteredDict = {}
            for locid in locationsDict:
                newFilteredDict[locid] = individualFilter(itemType, currentTime, locationsDict[locid], averageNum)
            return newFilteredDict

        def preProccessFilterAndComputeProbsMultipleItems(itemTypes, currentTime, locationsDict):
            newCombined = {}
            for locid in locationsDict:
                newCombined[locid] = {'latlong': locationsDict[locid]['latlong'],
                                    'prob': 1
                                    }

            filtered = [(preProccessFilterAndComputeProbs(itemType, currentTime, locationsDict))  for itemType in itemTypes]

            for individualFiltered in filtered:
                for locid in individualFiltered:
                    newCombined[locid]['prob'] *= individualFiltered[locid]['prob']

            return newCombined


        def swapPositions(l, pos1, pos2):
            l2 = l.copy()
            l2[pos1], l2[pos2] = l2[pos2], l2[pos1]
            return l2

        def calcPathTimeInPath(path, preProccessed, currentNodeId):
            probLeave = (1 - preProccessed[currentNodeId]['prob'])
            distToNext = np.linalg.norm( np.array(preProccessed[path[0]]['latlong']) - np.array(preProccessed[currentNodeId]['latlong'])  )

            if len(path) == 1:
                return probLeave * distToNext

            newDist = distToNext + calcPathTimeInPath(path[1:], preProccessed, path[0])
            return probLeave * newDist

        def calcPathTime(path, preProccessed, startingLocation):
            distToFirstStore = np.linalg.norm(np.array(startingLocation) - np.array(preProccessed[path[0]]['latlong']))
            return distToFirstStore + calcPathTimeInPath(path[1:], preProccessed, path[0])

        def minDistGradDescent(itemTypes, currentTime, locationsDict, startingLocation):
            preProccessed = preProccessFilterAndComputeProbsMultipleItems(itemTypes, currentTime, locationsDict)

            starting = list(preProccessed.keys())

            diff = 1
            i = 0
            while i<20 and diff != 0:
                i += 1
                bestFound, expDistToGo, diff = minPathOneStep(starting, preProccessed, startingLocation)
                starting = bestFound
                print(starting, expDistToGo, diff)

            return  bestFound, expDistToGo

        def minPathOneStep(starting, preProccessed, startingLocation):
            currentMinExpTime = calcPathTime(starting, preProccessed, startingLocation)
            firstTime = currentMinExpTime
            currentMinPath = starting

            for firstInx in range(len(starting)):
                for endingInx in range(len(starting))[firstInx+1:]:
                    candList = swapPositions(starting, firstInx, endingInx)
                    candExpTime = calcPathTime(candList, preProccessed, startingLocation)

                    if candExpTime < currentMinExpTime:
                        currentMinPath = candList
                        currentMinExpTime = candExpTime

            return currentMinPath, currentMinExpTime, firstTime - currentMinExpTime
        
        self.finish()
            
        
class GmapHandler(BaseHandler):
    async def get(self):
        def googlePlacesSearch(self):
            gmap = self.settings["gmaps"]
            value = gmap.places_nearby(location=(29.710336, -95.382414), keyword='drugstore|pharmacy', rank_by='distance')
            return value
        searchResult = googlePlacesSearch(self)
        for result in searchResult["results"]:
            self.settings["db"]["locations"].update_one(
                filter={
                    '_id': result["place_id"],
                },
                update={
                    '$setOnInsert': {
                        'latlong': (result["geometry"]["location"]["lat"], result["geometry"]["location"]["lng"]),
                        'stock': {},
                        'name': result["name"],
                        'vicinity': result['vicinity'],
                    },
                },
                upsert=True,
            )
        self.set_status(200)
        self.write(searchResult)


def make_app():
    settings = dict(
        cookie_secret=str(os.urandom(45)),\
        template_path=os.path.join(os.path.dirname(__file__), "templates"),
        static_path=os.path.join(os.path.dirname(__file__), "static"),
        default_handler_class=ErrorHandler,
        default_handler_args=dict(status_code=404),
        db=db,
        gmaps=gmaps
    )
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/api/report", PostHandler),
        (r"/api/status", StatusHandler),
        (r"/api/submitItem", SubmitHandler),
        (r"/api/gmap", GmapHandler),
        (r"/api/GetRoute", RouteHandler),

    ], **settings)


def main():
    app = make_app()
    return app


app = main()

if __name__ == '__main__':
    print("starting tornado server..........")
    app.listen(tornado.options.options.port)
    tornado.ioloop.IOLoop.current().start()