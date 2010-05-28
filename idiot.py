#!/usr/bin/env python
import hashlib
import re
import web
from ConfigParser import ConfigParser
from jinja2 import Environment, FileSystemLoader
from model import *
import controller
import os
from uuid import uuid4

urls = (
    '/?', 'IMain',
    '/login/?', 'ILogin',
    '/logout/?', 'ILogout',
    '/register/?', 'IRegister',
    '/page/(\d+)/?', 'IBrowse',
    '/project/(\w+)/?', 'IProject',
    '/project/(\w+)/issues/?', 'IProjectIssues',
    '/project/(\w+)/issues/page/(\d+)/?', 'IProjectIssues',
    '/project/(\w+)/issue/create/?', 'ICreateIssue',
    '/issue/create/?', 'ICreateIssue',
    '/issue/(\d+)/update/?', 'IUpdateIssue',
    '/user/(\w+)/?', 'IUser',
    '/admin/?', 'IAdmin',
	'/issue/(\d+)/?', 'IIssue',
    '/comment/(\d+)/?', 'IComment',
    '/comment/?', 'IComment',
    '/confirm/([a-zA-Z0-9\-]+)/?', 'IConfirmEmail',
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
web.debug(session)

PER_PAGE = 15

### Jinja2 Related functions. TODO: Move somewhere else.

def datetimeformat(value, format='%Y-%m-%d at %H:%M'):
    return value.strftime(format)

def render_template(template_name, context):
    extensions = context.pop('extensions', [])
    globals = context.pop('globals', {})

    jinja_env = Environment(
            loader=FileSystemLoader(os.path.join(os.path.dirname(__file__),
            'templates')), extensions=extensions)
    jinja_env.filters['datetimeformat'] = datetimeformat
    jinja_env.globals.update(globals)

    return jinja_env.get_template(template_name).render(context)


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
        if out_config['idiot_app_path'] in web.ctx.env.get('HTTP_REFERER','/'):
            out_config['last_url'] = web.ctx.env.get('HTTP_REFERER','/')
        return out_config

    def _issue_write_allowed(self, issue_seq):
        """Private method for determining if an issue is editable by
        the user."""

        if not hasattr(session, 'username') or session.username is False:
            username = ''
        else:
            username = session.username
        return Issue.has_write_access(issue_seq,
            username)[0].has_issue_write_access
    
    def _project_allowed(self, project_name):
        """Private method for determining if a project is viewable by
        the user."""
        web.debug("Logged: %s" % repr(self.logged()))
        if not hasattr(session, 'username') or session.username is False:
            username = ''
        else:
            username = session.username
        web.debug("Project Allowed: Username is %s" % username)
        access = Project.has_access(project_name,
                username)[0].has_project_access
        if Project.is_public(project_name)[0].project_is_public is True:
            return True
        elif self.logged() and access is True:
            web.debug("Project %s allowed for user %s" % \
                (project_name, username))
            return True
        else:
            web.debug("Project %s disallowed for user %s" % \
                (project_name, username))
            return False

    def __init__(self):
        self.config = self.read_config()
        web.debug("Session: %s" % repr(session))


class IMain(WebModule):
    def GET(self):
        if not self.logged():
            username = ''
        else:
            username = session.username
        results = Project().get_project_page(1, PER_PAGE, username)
        self.config['projects'] = results
        return render_template('browse.html', self.config)


class IBrowse(WebModule):
    def GET(self, page=1):
        if not self.logged():
            username = ''
        else:
            username = session.username
        results = Project().get_project_page(page, PER_PAGE, username)
        self.config['projects'] = results
        return render_template('browse.html', self.config)


class IComment(WebModule):

    form_vars = ['comment', 'issue_seq']

    def POST(self):
        in_vars = self._get_vars(self.form_vars)
        project = Issue.get(in_vars['issue_seq'])[0].project

        if self._project_allowed(project.name):
            comment = Comment.create(in_vars['issue_seq'], session.username,
                in_vars['comment'])
            self.config['comments'] = comment
            return web.seeother('/issue/%d#%d' % (comment[0].issue_seq, comment[0].seq))
            
    def GET(self, comment_seq):
        
        comment_thread = Comment.get_thread(comment_seq)
        issue = comment_thread[0].issue
        project = issue.project

        if self._project_allowed(project.name):
            self.config['comments'] = comment_thread
            self.config['issue'] = issue
            self.config['project'] = project
            return render_template('comment.html', self.config)
        else:
            self.config['error'] = 'You do not have permission to view ' + \
                'comments on this project.'
            return render_template('error.html', self.config)
            

class IIssue(WebModule):

    def GET(self, issue_id):
        issue = Issue.get(issue_id)[0]
        if self._project_allowed(issue.project.name):
            self.config['issue'] = issue
            self.config['project'] = issue.project
            self.config['author'] = issue.author
            self.config['write_allowed'] = \
                self._issue_write_allowed(issue_id)
            self.config['comments'] = []
            for thread in Comment.get_issue_threads(issue_id):
                web.debug("GRABBING THREAD: %s" % repr(thread))
                self.config['comments'].append(thread)
            if hasattr(session, 'last_project') and \
                hasattr(session, 'last_issue_page'):
                self.config['last_project'] = session.last_project
                self.config['last_issue_page'] = session.last_issue_page
        else:
            self.config['error'] = "This issue is attached to a project" + \
                " you do not have permission to access."
            return render_template('error.html', self.config)
        return render_template('issue.html', self.config)    


class IProject(WebModule):
    def GET(self, project_name):
        if self._project_allowed(project_name):
            web.debug("Project allowed.")
            project = Project.get(project_name)[0]
            web.debug('Project: %s' % repr(project))
            self.config['project'] = project
            result = Project.get_issue_page(project_name, 1, PER_PAGE)
            self.config['recent_issues'] = result
            self.config['owner'] = project.owner
            session.last_project = project_name
        else:
            web.debug("Project disallowed.")
            self.config['error'] = """You do not have permission to view
                this project."""
            return render_template('error.html', self.config)
        return render_template('project.html', self.config)

class IConfirmEmail(WebModule):
    def GET(self, auth_key):
        email_confirmed = EmailConfirm.confirm(auth_key)
        if email_confirmed[0].confirm_email is True:
            return render_template('email_confirmed.html', self.config)
        else:
            self.config['error'] = 'Confirmation not found. This email ' + \
                'address may have already been confirmed.'
            return render_template('error.html', self.config)

class IProjectIssues(WebModule):
    def GET(self, project_name, page=1):
        if self._project_allowed(project_name):
            self.config['project'] = Project.get(project_name)[0]
            result = Project.get_issue_page(project_name, page, PER_PAGE)
            self.config['issues'] = result
            self.config['max_page'] = \
                int(Project.get_max_issue_page(project_name,
                    PER_PAGE)[0].get_project_max_issue_page)
            web.debug("Page: " + str(page))
            if int(page) > 1:
                self.config['prev_page_url'] = \
                    "%sproject/%s/issues/page/%d" % \
                    (self.config['idiot_app_path'], project_name,
                    int(page) - 1)
            if int(page) < self.config['max_page']:
                self.config['next_page_url'] = \
                    "%sproject/%s/issues/page/%d" % \
                    (self.config['idiot_app_path'], project_name,
                    int(page) + 1)
            session.last_project = project_name
            session.last_issue_page = page
        else:
            self.config['error'] = """You do not have permission to view
                this project."""
        return render_template('project_issues.html', self.config)


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
        return render_template('user_profile.html', self.config)

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
            return web.seeother('/')
        else:
            self.config['error'] = 'Login failed.'
            return render_template('error.html', self.config) 

class IUpdateIssue(WebModule):
    
    form_vars = ['summary', 'description', 'severity',
        'issue_type', 'issue_status']

    def POST(self, seq):
        in_vars = self._get_vars(self.form_vars)
        if self.logged() and \
            self._issue_write_allowed(seq):

            Issue.update(seq, in_vars['summary'],
                in_vars['description'], in_vars['severity'],
                in_vars['issue_type'], in_vars['issue_status'])
            return web.seeother('/issue/%d' % int(seq))
    
    def GET(self, seq):
        if self.logged() and \
            self._issue_write_allowed(seq):

            issue = Issue.get(seq)[0]
            self.config['issue'] = issue
            #self.config['project'] = get_project(issue.project)
            self.config['severities'] = [severity.get_severities for \
                severity in Issue.severities()]
            self.config['issue_types'] = [issue_type.get_issue_types for \
                issue_type in Issue.types()]   
            self.config['issue_statuses'] = [issue_status.get_issue_statuses \
                for issue_status in Issue.statuses()]                 
            return render_template('update_issue.html', self.config)
        else:
            self.config['error'] = \
                'You do not have permission to update this issue.'
            return self.error(self.config)


class ICreateIssue(WebModule):

    form_vars = ['project', 'summary', 'description', 'severity', 'issue_type']

    def POST(self, project_name = None):
        if self.logged():
            in_vars = self._get_vars(self.form_vars)
            project = ''
            if 'project' in in_vars.keys():
                project = in_vars['project']
            elif project_name is not None:
                project = project_name
            else:
                self.config['error'] = 'No project specified.'
                return render_template('error.html', self.config)

            viewing_user = session.username
            try:
                new_issue = Issue.create(project, in_vars['summary'],
                    in_vars['description'], viewing_user,
                    in_vars['severity'], in_vars['issue_type'])[0]
                web.debug('New issue: %s' % repr(new_issue))
            except:
                self.config['error'] = 'An error occurred while ' + \
                    'creating this issue.'
                return render_template('error.html', self.config)
            
            return web.seeother('/issue/%d' % new_issue.seq)

    def GET(self, project_name = None):
        if self.logged():
            viewing_user = session.username
            if project_name is not None:
                self.config['project'] = Project.get(project_name)[0]
                web.debug(self.config['project'])
            self.config['projects'] = [project.name for project in \
                Project.all_for_user(viewing_user)]
            self.config['severities'] = [severity.get_severities for \
                severity in Issue.severities()]
            self.config['issue_types'] = [issue_type.get_issue_types for \
                issue_type in Issue.types()]
            return render_template('create_issue.html', self.config)
        else:
            self.config['error'] = 'You must be logged in to create issues.'
            return render_template('error.html', self.config)
        

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
        elif len(User.get_by_email(in_vars['email'])) > 0:
            self.config['error'] = 'This email address is already registered.'
        elif '@' not in in_vars['email']:
            self.config['error'] = 'This email address is not valid.'
        elif not re.match('^[a-zA-Z0-9_]+$', in_vars['username']):
            self.config['error'] = """Usernames must only contain alphanumeric
                characters or underscores (_)."""

        if self.config.has_key('error'):
            self.config['rejected_user_info'] = in_vars
            return render_template('register.html', self.config)
        else:
            new_user = User.create(in_vars['username'], in_vars['full_name'],
                in_vars['email'], in_vars['password'],
                in_vars['password_confirm'], in_vars['url'], False,
                in_vars['about_you'])[0]
            web.debug('New User: %s' % new_user)
            if not hasattr(new_user, 'username'):
                self.config['error'] = """An unexpected error occurred.
                    Please notify an administrator."""
                return render_template('error.html', self.config)
            #session.username = new_user.username
            self.config['new_user'] = new_user
            if len(new_user.full_name) > 0:
                self.config['first_name'] = new_user.full_name.split(' ')[0]
            else:
                self.config['first_name'] = new_user.username

            auth_key = str(uuid4())
            EmailConfirm.create(new_user.username, auth_key)
            controller.send_email_confirmation(new_user.full_name,
                new_user.email, auth_key)
            return render_template('register_success.html', self.config)

    def GET(self):
        return render_template('register.html', self.config)

class ILogout(WebModule):

    def GET(self):
        self.POST()

    def POST(self):
        session.logged_in = False
        del session.username
        return web.seeother(web.ctx.env.get('HTTP_REFERER','/'))


if __name__ == "__main__":
    app.run()
