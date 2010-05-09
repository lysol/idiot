#!/usr/bin/env python
import hashlib
import re
import web
from ConfigParser import ConfigParser
from web.contrib.template import render_jinja
from model import *


urls = (
    '/?', 'IMain',
    '/login/?', 'ILogin',
    '/logout/?', 'ILogout',
    '/register/?', 'IRegister',
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

    def _get_vars(self, var_list):
        result = {}
        for var in var_list:
            result[var] = getattr(web.input(), var)
        return result

    def logged(self):
        if session.get('logged_in', False):
            return True
        else:
            return False

    def read_config(self):
        web.debug('Path: %s' % web.ctx.path)
        in_config = ConfigParser()
        in_config.readfp(open('settings.conf'))
        out_config = dict([('idiot_' + x[0], x[1]) for x in \
            in_config.items('idiot')])
        if self.logged() is True:
            user = User.get(session.username)
            if len(user) == 0:
                session.logged_in = False
                del session.username
                out_config['logged'] = False
                out_config['yourself'] = None
            else:
                out_config['logged'] = True
                out_config['yourself'] = user[0]
        else:
            out_config['logged'] = False
            out_config['yourself'] = None
        out_config['session'] = web.debug(session) 
        return out_config

    def _project_allowed(self, project_name):
        """Private method for determining if a project is viewable by
        the user."""
        web.debug("Logged: %s" % repr(self.logged()))
        access = Project.has_access(project_name,
                session.username)[0].has_project_access
        if Project.is_public(project_name)[0].project_is_public is True:
            return True
        elif self.logged() and access is True:
            web.debug("Project %s allowed for user %s" % \
                (project_name, session.username))
            return True
        else:
            web.debug("Project %s disallowed for user %s" % \
                (project_name, session.username))
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
            return render.error(self.config)
        return render.issue(self.config)    

class IProject(WebModule):
    def GET(self, project_name):
        if self._project_allowed(project_name):
            web.debug("Project allowed.")
            result = Project.get(project_name)
            proj = result[0]
            web.debug('Project: %s' % repr(proj))
            self.config['project'] = proj
            result = Project.get_issue_page(project_name, 1, PER_PAGE)
            self.config['issues'] = result
        else:
            web.debug("Project disallowed.")
            self.config['error'] = "You do not have permission to view this project."
            return render.error(self.config)
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
        user = User.get(username)[0]
        if self.logged():
            viewing_user = session.username
        else:
            viewing_user = ''
        self.config['recent_issues'] = \
            User.recent_issues(username, viewing_user, PER_PAGE)
        self.config['recent_comments'] = \
            User.recent_comments(username, viewing_user, PER_PAGE)
        self.config['user'] = user
        return render.user_profile(self.config)

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

class IRegister(WebModule):
    
    form_vars = ['username', 'full_name', 'email', 'password',
        'password_confirm', 'url', 'about_you']

    def POST(self):
        in_vars = self._get_vars(self.form_vars)

        if in_vars['password'] != in_vars['password_confirm']:
            self.config['error'] = 'The passwords entered did not match.'
        elif len(in_vars['password']) < 6:
            self.config['error'] = \
                'You must specify a password of at least six characters.'
        elif len(User.get(in_vars['username'])) > 0:
            self.config['error'] = 'This username already exists.'
        elif '@' not in in_vars['email']:
            self.config['error'] = 'This email address is not valid.'
        elif not re.match('^[a-zA-Z0-9_]+$', in_vars['username']):
            self.config['error'] = """Usernames must only contain alphanumeric
                characters or underscores (_)."""

        if self.config.has_key('error'):
            self.config['rejected_user_info'] = in_vars
            return render.register(self.config)
        else:
            new_user = User.create(in_vars['username'], in_vars['full_name'],
                in_vars['email'], in_vars['password'],
                in_vars['password_confirm'], in_vars['url'], False,
                in_vars['about_you'])[0]
            web.debug('New User: %s' % new_user)
            if not hasattr(new_user, 'username'):
                self.config['error'] = """An unexpected error occurred.
                    Please notify an administrator."""
                return render.error(self.config)
            session.logged_in = True
            session.username = new_user.username
            self.config['new_user'] = new_user
            if len(new_user.full_name) > 0:
                self.config['first_name'] = new_user.full_name.split(' ')[0]
            else:
                self.config['first_name'] = new_user.username
            return render.register_success(self.config)

    def GET(self):
        return render.register(self.config)

class ILogout(WebModule):

    def GET(self):
        self.POST()

    def POST(self):
        session.logged_in = False
        del session.username
        return web.seeother(web.ctx.env.get('HTTP_REFERER','/'))


if __name__ == "__main__":
    app.run()
