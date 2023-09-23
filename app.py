import os
import json
import ast
import datetime
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
db = client.college

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


class ParamsHandler(BaseHandler):
    """
    GET handler for multiple parameters
    """

    def get(self, **params):
        print("get: ", params)
        self.set_status(200)
        self.finish({'ok': 'GET success'})


class MainHandler(BaseHandler):
    """
    GET handler for main page, loads the index.html
    """

    def get(self):
        self.set_status(200)
        self.write({'data1' : ['location1','location2']})


class ItemListHandler(BaseHandler):
    """
    GET handler for returning list of all possible items
    """

    def get(self):
        self.set_status(200)
        self.write("Items")



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
        cookie_secret=str(os.urandom(45)),
        template_path=os.path.join(os.path.dirname(__file__), "templates"),
        static_path=os.path.join(os.path.dirname(__file__), "static"),
        default_handler_class=ErrorHandler,
        default_handler_args=dict(status_code=404)
    )
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/api/status", StatusHandler),
        (r"/api/itemList/", ItemListHandler),
        (r"/api/submitItem/", SubmitHandler),
        (r"/api/GetRoute/", RouteHandler),
        (r"/api/tornado/(?P<one>[^\/]+)/?(?P<two>[^\/]+)?/?(?P<three>[^\/]+)?/?(?P<four>[^\/]+)?", ParamsHandler),
    ], **settings)


def main():
    app = make_app()
    return app


app = main()

if __name__ == '__main__':
    print("starting tornado server..........")
    print("Mongo Connection String: " + os.environ["COSMOS_CONNECTION_STRING"])
    app.listen(tornado.options.options.port)
    tornado.ioloop.IOLoop.current().start()