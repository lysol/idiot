import web
from web.contrib.template import render_jinja
import controller


urls = (
    '/', 'Main',
    '/page/(\d+)/', 'Browse',
    '/ticket/(\d+)/', 'Issue',
    '/project/(\w+)/', 'Project',
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
    def GET(self, issue_id):
        return controller.issue(session, render, issue_id)

class Project:
    def GET(self, project_id):
        return controller.project(session, render, project_id)

class User:
    def GET(self, username):
        return controller.user(session, render, username)

class Admin:
    def GET(self):
        return controller.admin(session, render)


if __name__ == "__main__":
    app.run()
