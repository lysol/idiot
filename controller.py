from ConfigParser import ConfigParser
from simpycity import config

config.host = 'localhost'
config.port = 5432
config.user = 'idiot'
config.password = 'idiot'
config.database = 'idiot'


def read_config():
    config = ConfigParser()
    config.readfp(open('settings.conf'))
    return dict(config.items('idiot'))

def logged():
    if session.logged_in:
        return True
    else:
        return False

def browse(session, render, page):
    config = read_config()

    if logged():
        results = Project.get_public_project_page(page, PER_PAGE, session.username)
    else:
        results = Project.get_user_project_page(page, PER_PAGE, session.username)
    config.update(results)
    return render.browse(config)

def issue(session, render, issue_id):
    # TODO
    # Check if issue is part of a project user is attached to.
    # If so, display it, otherwise, deny.
    pass

def project(session, render, project_name):
    # TODO
    # Check if user is attached to the project or an admin.
    # If so, display it, or kick back to the main apge.
    pass

def user(session, render, username):
    # TODO
    # Display a user profile.
    pass

def admin(session, render):
    # TODO
    # Admin panel
