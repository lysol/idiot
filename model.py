import web

from simpycity.core import Function, Raw
from simpycity.model import Construct, SimpleModel
from simpycity import config

config.host = 'localhost'
config.port = 5432
config.user = 'idgit'
config.password = 'idgit'
config.database = 'idgit'



class Project(SimpleModel):

    table = ['name', 'description', 'owner']
    
    all = Function("get_all_projects")
    get = Function("get_project", ['name'])
    delete = Function("delete_project", ['name'])
    get_all_issues = Function("get_project_issues", ['name'])
    get_issue_page = Function("get_project_issue_page", ['name', 'page'])
    create = Function("create_project", ['name', 'description', 'owner'])
    update = Function("update_project", ['name', 'description'])
    get_permissions = Function("get_project_permissions", ['project'])


class Issue(SimpleModel):

    table = ['seq', 'project', 'summary', 'description', 'author']
    
    all = Function("get_all_issues")
    get = Function("get_issue", ['seq'])
    get_page = Function ("get_issue_page", ['project', 'page'])
    delete = Function("delete_issue", ['seq'])
    create = Function("create_issue", ['project', 'summary', 'description'])
    update = Function("update_issue", ['seq', 'summary', 'description'])


class User(SimpleModel):

    table = ['username', 'full_name', 'email', 'password', 'website']

    all = Function("get_all_users")
    get = Function("get_user", ['username'])
    get_page = Function("get_user_page", ['page'])
    delete = Function ("delete_user", ['username'])
    create = Function("modify_user", ['username', 'full_name', 'email',
        'password', 'password_again', 'website'])
    update = Function("modify_user". ['username', 'full_name', 'email',
        'password', 'password_again', 'website'])
    get_permissions = Function("get_user_permissions", ['username'])


class Permission(SimpleModel):
    
    table = ['seq', 'project', 'username', 'post_issues', 'post_comments']

    all = Function("get_all_permissions")
    get = Function("get_permission", ['seq'])
    delete = Function("delete_permission", ['seq'])
    create = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'])
    update = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'])

