import web
from web.contrib.template import render_jinja
import controller


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

app = web.application(urls, globals())
session = web.session.Session(app, web.session.DiskStore('sessions'),
    initializer={'nothing': None})
render = render_jinja('templates', encoding = 'utf-8')


class Main:
    def GET(self):
        return web.seeother('/page/1/')

class Browse:
    def GET(self, page):
        return controller.browse(session, render, page)

class Issue:
    def GET(self, project_name, issue_id):
        return controller.issue(session, render, project_name, issue_id)

class Project:
    def GET(self, project_name):
        return controller.project(session, render, project_name)

class User:
    def GET(self, username):
        return controller.user(session, render, username)

class Admin:
    def GET(self):
        return controller.admin(session, render)

class Login:
    def POST(self, username, password):
        if session = controller.login(session, username, password):
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
