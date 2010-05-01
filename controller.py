from ConfigParser import ConfigParser
from simpycity import config
from model import *

config.host = 'localhost'
config.port = 5432
config.user = 'idiot'
config.password = 'idiot'
config.database = 'idiot'

PER_PAGE = 20

def read_config():
    config = ConfigParser()
    config.readfp(open('settings.conf'))
    out_config = dict([('idiot_' + x[0], x[1]) for x in config.items('idiot')])
    return out_config

def logged(session):
    if hasattr(session,'logged_in') and session.logged_in:
        return True
    else:
        return False

def browse(session, render, page):
    config = read_config()

    if not logged(session):
        results = Project.get_public_project_page(page, PER_PAGE)
    else:
        results = Project.get_user_project_page(page, PER_PAGE, session.username)
    config['projects'] = results
    return render.browse(config)

def issue(session, render, issue_id):
    # TODO
    # Check if issue is part of a project user is attached to.
    # If so, display it, otherwise, deny.
    pass

def project(session, render, project_name):
    config = read_config()
    # TODO finish
    pass

def user(session, render, username):
    # TODO
    # Display a user profile.
    pass

def admin(session, render):
    # TODO
    # Admin panel
    pass
