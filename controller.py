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

def browser(session, page):
    if logged():
        results = Project.get_public_project_page(page, PER_PAGE, session.username)
    else:
        results = Project.get_user_project_page(page, PER_PAGE, session.username)
    return {'results': results}
