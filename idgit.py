import web
import model
import controller

urls = (
    '/', 'Browse',
    '/page/(.*)', 'Browse',
    '/ticket/(.*)', 'Issue',
    '/project/(.*)', 'Project',
    '/user/(.*)', 'User',
    '/admin/', 'Admin',
)

class Browse:

    def GET(self, page):
        pass


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
