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


class Main:
    def GET(self):
        return Browse.GET(1)

class Browse:
    def GET(self, page):
        kwargs = controller.browse(session, page)
        return render.browse(kwargs)

class Issue:
    def GET(self, issue_id):
        kwargs = controller.issue(session, issue_id)
        return render.issue(kwargs)

class Project:
    def GET(self, project_id):
        kwargs = controller.project(session, project_id)
        return render.project(kwargs)

class User:
    def GET(self, user_id):
        kwargs = controller.user(session, user_id)
        return render.user(kwargs)

class Admin:
    def GET(self):
        kwargs = controller.admin(session)
        return render.admin(kwargs)


if __name__ == "__main__":
    app.run()
