import web
import model

urls = (
    '/', 'Browse',
    '/page/(.*)', 'Browse',
    '/ticket/(.*)', 'Issue',
    '/project/(.*)', 'Project',
    '/user/(.*)', 'User',
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
