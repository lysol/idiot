import hashlib
from ConfigParser import ConfigParser
from simpycity import config
from model import *

in_config = ConfigParser()
in_config.readfp(open('settings.conf'))
items = dict(in_config.items('database'))

config.host = items['host']
config.port = items['port']
config.user = items['user']
config.password = items['password']
config.database = items['database']

PER_PAGE = 20

def read_config():
    in_config = ConfigParser()
    in_config.readfp(open('settings.conf'))
    out_config = dict([('idiot_' + x[0], x[1]) for x in \
        in_config.items('idiot')])
    return out_config

def logged(session):
    if hasattr(session,'logged_in') and session.logged_in
        and User.check_login(session.username, session.password):
        return True
    else:
        return False

def browse(session, render, page):
    kwargs = read_config()

    if not logged(session):
        results = Project.get_public_project_page(page, PER_PAGE)
    else:
        results = Project.get_user_project_page(page, PER_PAGE, session.username)
    kwargs['projects'] = results
    return render.browse(kwargs)

def issue(session, render, issue_id):
    # TODO
    # Check if issue is part of a project user is attached to.
    # If so, display it, otherwise, deny.
    pass

def project(session, render, project_name):
    kwargs = read_config()
    if (not logged(session) and \
        Project.is_public(project_name).fetchall()[0][0] is True) or \
        (logged(session) and \
        Project.has_access(project_name, session.username) is True):
        result = Project.get(project_name)
        kwargs['project'] = result.fetchall()[0]
        result = Project.get_issue_page(project_name, 1, PER_PAGE)
        kwargs['issues'] = result
    else:
        kwargs['error'] = "You do not have permission to view this project."
    return render.project(kwargs)

def project_issues(session, render, project_name, page):
    kwargs = read_config()
    if (not logged(session) and \
        Project.is_public(project_name).fetchall()[0][0] is True) or \
        (logged(session) and \
        Project.has_access(project_name, session.username) is True):
        result = Project.get(project_name)
        kwargs['project'] = result.fetchall()[0]
        result = Project.get_issue_page(project_name, page, PER_PAGE)
        kwargs['issues'] = result
    else:
        kwargs['error'] = "You do not have permission to view this project."
    return render.project_issues(kwargs)


def user(session, render, username):
    # TODO
    # Display a user profile.
    pass

def admin(session, render):
    # TODO
    # Admin panel
    pass



def login(session, username, password):
    if User.login(username, password):
        session.logged_in = True
        session.username = username
        session.password = hashlib.md5(password).hexdigest()
        return True
    else:
        return False
