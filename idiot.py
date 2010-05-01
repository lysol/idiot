#!/usr/bin/env python
import web
from web.contrib.template import render_jinja
from controller import Controller

urls = (
    '/', 'Main',
    '/login/', 'Login',
    '/logout/', 'Logout',
    '/page/(\d+)/', 'Browse',
    '/project/(\w+)/', 'Project',
    '/project/(]w+)/issues/', 'ProjectIssues',
    '/project/(\w+)/issue/(\d+)/', 'Issue',
    '/user/(\w+)/', 'User',
    '/admin/', 'Admin',
)

web.config.debug = True

app = web.application(urls, globals())
session = web.session.Session(app, web.session.DiskStore('sessions'),
    initializer={'nothing': None})
render = render_jinja('templates', encoding = 'utf-8')
controller = Controller(session, render)

class Main:
    def GET(self):
        return web.seeother('/page/1/')

class Browse:
    def GET(self, page):
        return controller.browse(page)

class Issue:
    def GET(self, project_name, issue_id):
        return controller.issue(project_name, issue_id)

class Project:
    def GET(self, project_name):
        return controller.project(project_name)

class User:
    def GET(self, username):
        return controller.user(username)

class Admin:
    def GET(self):
        return controller.admin()

class Login:
    def POST(self, username, password):
        session = controller.login(username, password)
        if controller.logged():
            # Login succeeded.
            return web.seeother('/')
        else:
            # Login failed
            # TODO
            pass

class Logout:
    def POST(self):
        controller.logout(session)
        return web.seeother('/')

if __name__ == "__main__":
    app.run()
