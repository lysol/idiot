#!/usr/bin/env python
from ConfigParser import ConfigParser
import hashlib
import web
from web.contrib.template import render_jinja
from model import *


urls = (
    '/?', 'IMain',
    '/login/?', 'ILogin',
    '/logout/?', 'ILogout',
    '/page/(\d+)/?', 'IBrowse',
    '/project/(\w+)/?', 'IProject',
    '/project/(\w+)/issues/?', 'IProjectIssues',
    '/user/(\w+)/?', 'IUser',
    '/admin/?', 'IAdmin',
	'/issue/(\d+)/?', 'IIssue'
)

web.config.debug = False 

app = web.application(urls, globals())

session_defaults = {
    'logged': False,
    'username': False,
    'password': False
}

session = web.session.Session(app, web.session.DiskStore('sessions'),
    initializer=session_defaults)
render = render_jinja('templates', encoding = 'utf-8')

PER_PAGE = 20

class WebModule:

    def logged(self):
        if session.get('logged_in', False):
            return True
        else:
            return False

    def read_config(self):
        in_config = ConfigParser()
        in_config.readfp(open('settings.conf'))
        out_config = dict([('idiot_' + x[0], x[1]) for x in \
            in_config.items('idiot')])
        if self.logged() is True:
            out_config['logged'] = True
            user = User.get(session.username)[0]
            out_config['yourself'] = user
        else:
            out_config['logged'] = False
            out_config['yourself'] = None
        out_config['session'] = web.debug(session) 
        return out_config

    def _project_allowed(self, project_name):
        """Private method for determining if a project is viewable by
        the user."""
        if (not self.logged() and \
            Project.is_public(project_name)[0].project_is_public is True) or \
            (self.logged() and \
            Project.has_access(project_name, session.username) is True):
            return True
        else:
            return False

    def __init__(self):
        self.config = self.read_config()


class IMain(WebModule):
    def GET(self):
        return web.seeother('/page/1/')

class IBrowse(WebModule):
    def GET(self, page=1):
        if not self.logged():
            results = Project().get_public_project_page(page, PER_PAGE)
        else:
            results = Project().get_user_project_page(page, PER_PAGE,
                session.username)
        self.config['projects'] = results
        return render.browse(self.config)

class IIssue(WebModule):
    def GET(self, issue_id):
        issue = Issue.get(issue_id)[0]
        if self._project_allowed(issue.project):
            self.config['issue'] = issue
            self.config['project'] = Project.get(issue.project)[0]
            self.config['author'] = User.get(issue.author)[0]
        else:
            self.config['error'] = "This issue is attached to a project" + \
                " you do not have permission to access."
        return render.issue(self.config)    

class IProject(WebModule):
    def GET(self, project_name):
        if self._project_allowed(project_name):
            result = Project.get(project_name)
            self.config['project'] = result[0]
            result = Project.get_issue_page(project_name, 1, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return render.project(self.config)

class IProjectIssues(WebModule):
    def GET(self, project_name, page=1):
        if self._project_allowed(project_name):
            result = Project.get(project_name)
            self.config['project'] = result[0]
            result = Project.get_issue_page(project_name, page, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return render.project_issues(self.config)

class IUser(WebModule):
    def GET(self, username):
        # TODO
        # Display a user profile.
        pass

class IAdmin(WebModule):
    def GET(self):
        # TODO
        # Admin panel
        pass

class ILogin(WebModule):

    def GET(self):
        return web.seeother('/')

    def POST(self):
        username, password = web.input().username, web.input().password 
        if User.login(username, password)[0]['user_login'] is True:
            session.logged_in = True
            session.username = username
            return web.seeother(web.ctx.env.get('HTTP_REFERER','/'))
        else:
            self.config['error'] = 'Login failed.'
            return render.error(self.config) 
        
class ILogout(WebModule):

    def GET(self):
        self.POST()

    def POST(self):
        session.logged_in = False
        del session.username
        return web.seeother(web.ctx.env.get('HTTP_REFERER','/'))


if __name__ == "__main__":
    app.run()
