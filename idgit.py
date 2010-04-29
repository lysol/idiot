import web
from web.contrib.template import render_jinja
from model import *
import controller

urls = (
    '/', 'Browse',
    '/page/(.*)', 'Browse',
    '/ticket/(.*)', 'Issue',
    '/project/(.*)', 'Project',
    '/user/(.*)', 'User',
    '/admin/', 'Admin',
)

app = web.application(urls, globals())
session = web.session.Session(app, web.session.DiskStore('sessions'))
render = render_jinja('templates', encoding = 'utf-8')

PER_PAGE = 20

def logged():
    if session.logged_in:
        return True
    else:
        return False


class Main:
    def GET(self):
        return Browse.GET(1)

class Browse:
    def GET(self, page):
        # do something with a controller here

class Issue:
    def GET(self, issue_id):
        pass


class Project:
    def GET(self, project_id):
        pass


class User:
    def GET(self, user_id):
        pass


class Admin:
    def GET(self):
        pass

if __name__ == "__main__":
    app.run()
