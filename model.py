import re
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


class Function:

    def _get_fks(self):
        if self.fks is not None:
            return eval(self.fks + '.foreign_keys')
        else:
            return {}

    def __call__(self, *arguments):
        """Execute a programmatically defined method using a tuple list of
        argument names and values."""

        query = """
            SELECT * FROM "%s"."%s"(%s);
        """
        args = ', '.join(["$%s" % arg for arg in self.arguments])
        query = query % (self.schema, self.function_name, args)
        arg_dict = {}
        for i in range(len(self.arguments)):
            arg_dict[self.arguments[i]] = arguments[i]
        web.debug("Query: %s" % repr(query))
        web.debug("Vars: %s" % repr(arg_dict))
        results = []
        for result in [result for result in db.query(query, vars=arg_dict)]:
            for key in result.keys():
                #web.debug("Checking key %s" % key)
                if key in self._get_fks().keys() and result[key] is not None:
                    web.debug("Adding child.")
                    child = self._get_fks()[key](result[key])[0]
                    key = re.sub('_seq$', '', key)
                    result[key] = child
            web.debug("Appending result.")            
            web.debug(repr(result))
            results.append(result)
        return results
            

    def __init__(self, function_name, arguments=[], fks=None,
        schema='public'):
        self.function_name = function_name
        self.arguments = arguments
        self.schema = schema
        self.fks = fks


class Raw:

    def _get_fks(self):
        if self.fks is not None:
            return eval(self.fks + '.foreign_keys')
        else:
            return {}

    def __call__(self, *arguments):
        """Execute a query with arguments.  Must follow web.py standard
        queries."""

        arg_dict = {}
        for i in range(len(self.arguments)):
            arg_dict[self.arguments[i]] = arguments[i]
        web.debug("Query: %s" % repr(self.query))
        web.debug("Vars: %s" % repr(arg_dict))
        results = []
        for result in [result for result in db.query(self.query,
            vars=arg_dict)]:
            for key in result.keys():
                #web.debug("Checking key %s" % key)
                if key in self._get_fks().keys() and result[key] is not None:
                    web.debug("Adding child.")
                    child = self._get_fks()[key](result[key])[0]
                    key = re.sub('_seq$', '', key)
                    result[key] = child
            web.debug("Appending result.")
            web.debug(repr(result))
            results.append(result)
        return results

    def __init__(self, query, arguments=[], fks=None):
        self.query = query
        self.arguments = arguments
        self.fks = fks


class User:

    all = Function("get_all_users")
    get = Function("get_user", ['username'])
    get_page = Function("get_user_page", ['page'])
    delete = Function ("delete_user", ['username'])
    create = Function("create_user", ['username', 'full_name', 'email',
        'password', 'password_again', 'website', 'admin', 'about'])
    update = Function("modify_user", ['username', 'full_name', 'email',
        'password', 'password_again', 'website'])
    login = Function("user_login", ['login_username', 'login_password'])
    check_login = Function("user_verify", ['login_username', 'md5_password'])
    get_permissions = Function("get_user_permissions", ['username'],
        fks='Permission')
    recent_comments = Function("get_user_recent_comments",
        ['viewed_user', 'viewing_user', 'count'], fks='Comment')
    recent_issues = Function("get_user_recent_issues", 
        ['viewed_user', 'viewing_user', 'count'], fks='Issue')


class Project:

    foreign_keys = {
        'owner': User.get
        }

    all = Function("get_projects", ['public_only'], fks='Project')
    get = Function("get_project", ['project_name'], fks='Project')
    all_for_user = Function("get_user_projects", ['username'],
        fks='Project')
    has_access = Function("has_project_access", ['project_name', 'username'])
    is_public = Function("project_is_public", ['project_name'])
    delete = Function("delete_project", ['name'])
    get_all_issues = Function("get_project_issues", ['name'],
        fks='Issue')
    get_issue_page = Function("get_project_issue_page", 
        ['name', 'page', 'per_page'], fks='Issue')
    get_project_page = \
        Function("get_user_project_page", ['page', 'per_page', 'username'],
        'Project')      
    get_max_issue_page = Function("get_project_max_issue_page",
        ['project', 'per_page'])
    owner = Raw("SELECT owner FROM project WHERE name = $project",
        ["project"])
    create = Function("create_project", 
        ['name', 'description', 'owner', 'public'], fks='Project')
    update = Function("modify_project", ['name', 'description', 'public'])
    get_permissions = Function("get_project_permissions", ['project'])


class Issue:

    foreign_keys = {
        'author': User.get,
        'project': Project.get
        }

    all = Function("get_all_issues", fks='Issue')
    get = Raw("SELECT * FROM issue WHERE seq = $seq", ['seq'],
        fks='Issue')
    delete = Function("delete_issue", ['seq'])
    create = Function("create_issue",
        ['project', 'summary', 'description', 'author', 'severity',
        'issue_type'], fks='Issue')
    update = Function("modify_issue",
        ['seq', 'summary', 'description', 'severity', 'issue_type', 'status'])
    get_threads = Function("get_issue_threads", ['seq'],
        fks='Comment')
    severities = Function("get_severities")
    types = Function("get_issue_types")
    statuses = Function("get_issue_statuses")
    has_write_access = Function("has_issue_write_access",
        ['issue_seq', 'username'])


class Permission:
    
    foreign_keys = {
        'project': Project.get,
        'username': User.get
        }

    all = Function("get_all_permissions", fks='Permission')
    get = Function("get_permission", ['seq'], fks='Permission')
    delete = Function("delete_permission", ['seq'])
    create = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'], fks='Permission')
    update = Function("modify_permission", ['project', 'username',
        'post_issues', 'post_comments'])


class Comment:
    
    foreign_keys = {
        'author': User.get,
        'issue_seq': Issue.get,
        'parent_seq': Issue.get
        }

    all = Function("get_all_comments", fks='Comment')
    get = Function("get_comment", ['seq'], fks='Comment')
    get_thread = Function("get_thread", ['seq'], fks='Comment')
    create = Function("create_thread", ['issue_seq', 'author', 'comment'],
        fks='Comment')
    update = Function("modify_comment", ['seq', 'comment'])
    delete = Function("delete_comment", ['seq'])
    reply = Function("reply_comment", ['seq', 'author', 'comment'],
        fks='Comment')
    get_issue_threads = Function("get_issue_threads", ['issue_seq'],
        fks='Comment')
