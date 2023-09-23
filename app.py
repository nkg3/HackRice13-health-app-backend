import os
import json
import ast
import time
import tornado.httpserver
import tornado.options
import tornado.ioloop
import tornado.web
import tornado.wsgi
import motor.motor_tornado
from bson import ObjectId
from dotenv import load_dotenv

load_dotenv()
client = motor.motor_tornado.MotorClient(os.environ["COSMOS_CONNECTION_STRING"])
db = client.get_database('primary')

from tornado import gen, web

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

    def post(self):
        self.set_status(200)
        self.write("SUBMITTED")


class RouteHandler(BaseHandler):
    """
    POST handler for getting the best route
    """

    def post(self):
        self.set_status(200)
        self.write("ROUTE")


def make_app():
    settings = dict(
        cookie_secret=str(os.urandom(45)),\
        template_path=os.path.join(os.path.dirname(__file__), "templates"),
        static_path=os.path.join(os.path.dirname(__file__), "static"),
        default_handler_class=ErrorHandler,
        default_handler_args=dict(status_code=404),
        db=db,
    )
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/api/report", PostHandler),
        (r"/api/status", StatusHandler),
        (r"/api/submitItem", SubmitHandler),
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