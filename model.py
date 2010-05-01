import web
from ConfigParser import ConfigParser

in_config = ConfigParser()
in_config.readfp(open('settings.conf'))
items = dict(in_config.items('database'))

host = items['host']
port = items['port']
user = items['user']
password = items['password']
database = items['database']
dbtype = items['type']

db = web.database(dbn=dbtype, port=port, db=database,
    user=user, pw=password, host=host)


class Model:
    """Attempt to provide a rational interface to database functions."""

    def _exec_function(self, method_name, argument_list, returns_set,
        schema_name='public'):
        """Execute a programmatically defined method."""

        if returns_set:
            query = """
                SELECT * FROM "%s"."%s"(%s);
            """
        else:
            query = """
                SELECT "%s"."%s"(%s);
            """
        args = ', '.join(['"%s"' % arg for arg in argument_list])
        return db.query(query % (schema_name, method_name, args))

    def _add_method(self, method_name, argument_list, returns_set):
        """Add a dummy method that calls _exec_function for a function."""
        setattr(self, lambda method_name, argument_list, returns_set:
            self._exec_function(method_name, argument_list, returns_set))

    def __init__(self):
        function_methods = filter(lambda x: hasattr(x, 'function_name'),
            dir(self))
        for function_method in function_methods:
            method_name = getattr(function_method, 'function_name')
            arguments = getattr(function_method, 'argument_list')
            returns_set = getattr(function_method, 'returns_set')
            self._add_method(function_name, arguments, returns_set)
        

class Function:
    
    def __init__(self, function_name, argument_list=[], returns_set=False):
        self.function_name = function_name
        self.argument_list = argument_list
        self.returns_set = returns_set
        self.__modeltype__ = 'Function'

class Raw:
    
    def __init__(self, query, argument_list=[], returns_set=True):
        self.__modeltype__ = 'Raw'
        # TODO Add other attribute defs

class Project:

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


class Issue:

    all = Function("get_all_issues")
    get = Function("get_issue", ['seq'])
    #get_page = Function("get_issue_page", ['project', 'page'])
    delete = Function("delete_issue", ['seq'])
    create = Function("create_issue", ['project', 'summary', 'description', 'author'])
    update = Function("modify_issue", ['seq', 'summary', 'description'])
    get_threads = Function("get_issue_threads", ['seq'])


class User:

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


class Permission:
    
    all = Function("get_all_permissions")
    get = Function("get_permission", ['seq'])
    delete = Function("delete_permission", ['seq'])
    create = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'])
    update = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'])


class Comment:
    
    all = Function("get_all_comments")
    get = Function("get_comment", ['seq'])
    get_thread = Function("get_thread", ['seq'])
    create = Function("create_thread", ['project', 'author', 'comment'])
    update = Function("modify_comment", ['seq', 'comment'])
    delete = Function("delete_comment", ['seq'])
    reply = Function("reply_comment", ['seq', 'author', 'comment'])
