import smtplib
from ConfigParser import ConfigParser

def send_email_confirmation(name, email_address, auth_key):
      
    in_config = ConfigParser()
    in_config.readfp(open('settings.conf'))
    email_config = dict(in_config.items('email'))
    idiot_config = dict(in_config.items('idiot'))

    message = "From: Idiot <%s>\n" % email_config['from_address'] + \
        "To: %s <%s>\n" % (name, email_address) + \
        "Subject: Confirm your email address\n\n" + \
        "To use the %s issue tracker at %s" \
            % (idiot_config['title'], idiot_config['url']) + \
        " you must confirm your email address using the following " + \
        "link:\n\n%s/confirm/%s" % (idiot_config['url'], auth_key) + \
        "\n\nIf you cannot click the link, copy and paste it into the " + \
        "address bar of your browser."
    if email_config.has_key('port'):
        port = email_config['port']
    else:
        port = 25
    smtp = smtplib.SMTP(email_config['host'], port)
    if email_config.has_key('username') and \
        email_config.has_key('password'):
        smtp.login(email_config['username'], email_config['password'])
    smtp.sendmail(email_config['from_address'], email_address, message)
    smtp.quit()
