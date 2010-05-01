import web

from simpycity.core import Function, Raw
from simpycity.model import Construct, SimpleModel


class Project(SimpleModel):

    table = ['name', 'description', 'owner']
    
    all = Function("get_projects", ['public_only'])
    get = Function("get_project", ['project_name'])
    has_access = Function("has_project_access", ['project_name', 'username'])
    is_public = Function("project_is_public", ['project_name'])
    delete = Function("delete_project", ['name'])
    get_all_issues = Function("get_project_issues", ['name'])
    get_issue_page = Function("get_project_issue_page", 
        ['name', 'page', 'per_page'])
    get_user_project_page = \
        Function("get_user_project_page", ['page', 'per_page', 'username'])
    get_public_project_page = \
        Function("get_public_project_page", ['page', 'per_page'])        
    get_max_issue_page = Raw("SELECT count(*) FROM issue WHERE project = %s", ["project"])
    create = Function("create_project", ['name', 'description', 'owner', 'public'])
    update = Function("modify_project", ['name', 'description', 'public'])
    get_permissions = Function("get_project_permissions", ['project'])


class Issue(SimpleModel):

    table = ['seq', 'project', 'summary', 'description', 'author']
    
    all = Function("get_all_issues")
    get = Function("get_issue", ['seq'])
    #get_page = Function("get_issue_page", ['project', 'page'])
    delete = Function("delete_issue", ['seq'])
    create = Function("create_issue", ['project', 'summary', 'description', 'author'])
    update = Function("modify_issue", ['seq', 'summary', 'description'])
    get_threads = Function("get_issue_threads", ['seq'])


class User(SimpleModel):

    table = ['username', 'full_name', 'email', 'password', 'website', 'admin']

    all = Function("get_all_users")
    get = Function("get_user", ['username'])
    get_page = Function("get_user_page", ['page'])
    delete = Function ("delete_user", ['username'])
    create = Function("create_user", ['username', 'full_name', 'email',
        'password', 'password_again', 'website', 'admin'])
    update = Function("modify_user", ['username', 'full_name', 'email',
        'password', 'password_again', 'website'])
    login = Function("user_login", ['login_username', 'login_password'])
    check_login = Function("user_verify", ['login_username', 'md5_password'])
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


class Comment(SimpleModel):
    
    table = ['seq', 'author', 'comment', 'timestamp', 'project', 'parent_seq']

    all = Function("get_all_comments")
    get = Function("get_comment", ['seq'])
    get_thread = Function("get_thread", ['seq'])
    create = Function("create_thread", ['project', 'author', 'comment'])
    update = Function("modify_comment", ['seq', 'comment'])
    delete = Function("delete_comment", ['seq'])
    reply = Function("reply_comment", ['seq', 'author', 'comment'])
