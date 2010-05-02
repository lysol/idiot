import hashlib
from ConfigParser import ConfigParser
from model import *

PER_PAGE = 20

class Controller():

    def _project_allowed(self, project_name):
        """Private method for determining if a project is viewable by
        the user."""
        if (not self.logged() and \
            Project.is_public(project_name)[0].project_is_public is True) or \
            (self.logged() and \
            Project.has_access(project_name, self.session.username) is True):
            return True
        else:
            return False

    def read_config(self):
        in_config = ConfigParser()
        in_config.readfp(open('settings.conf'))
        out_config = dict([('idiot_' + x[0], x[1]) for x in \
            in_config.items('idiot')])
        if self.logged():
            out_config['logged'] = True
            out_config['username'] = self.session.username
        return out_config

    def logged(self):
        if hasattr(self.session,'logged_in') and self.session.logged_in and \
            User.check_login(self.session.username, self.session.password):
            return True
        else:
            return False

    def browse(self, page):
        if not self.logged():
            results = Project.get_public_project_page(page, PER_PAGE)
        else:
            results = Project.get_user_project_page(page, PER_PAGE,
                self.session.username)
        self.config['projects'] = results
        return self.render.browse(self.config)

    def issue(self, issue_id):
        issue = Issue.get(issue_id)[0]
        if self._project_allowed(issue.project):
            self.config['issue'] = issue
            self.config['project'] = Project.get(issue.project)[0]
            self.config['author'] = User.get(issue.author)[0]
        else:
            self.config['error'] = "This issue is attached to a project" + \
                " you do not have permission to access."
        return self.render.issue(self.config)



    def project(self, project_name):
        if self._project_allowed(project_name):
            result = Project.get(project_name)
            self.config['project'] = result[0]
            result = Project.get_issue_page(project_name, 1, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return self.render.project(self.config)

    def project_issues(self, project_name, page):
        if self._project_allowed(project_name):
            result = Project.get(project_name)
            self.config['project'] = result[0]
            result = Project.get_issue_page(project_name, page, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return self.render.project_issues(self.config)

    def user(self, username):
        # TODO
        # Display a user profile.
        pass

    def admin(self):
        # TODO
        # Admin panel
        pass

    def login(self, username, password):
        if User.login(username, password):
            self.session.logged_in = True
            self.session.username = username
            self.session.password = hashlib.md5(password).hexdigest()
            return session
        else:
            return session

    def __init__(self, session, render):
        self.session = session
        self.render = render
        self.config = self.read_config()
        # Initialize common stuff here

