from simpycity import config

config.host = 'localhost'
config.port = 5432
config.user = 'idgit'
config.password = 'idgit'
config.database = 'idgit'


def logged():
    if session.logged_in:
        return True
    else:
        return False

def browser(session, render, page):
    if logged():
        results = Project.get_public_project_page(page, PER_PAGE, session.username)
    else:
        results = Project.get_user_project_page(page, PER_PAGE, session.username)
    return {'results': results}

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
    # Display a use profile.
    pass
