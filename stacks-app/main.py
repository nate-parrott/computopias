#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
import json
import urllib2
import urllib
from apns import APNs, Frame, Payload
import time

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

def tokens_for_user_id(uid):
    url = 'https://computopias.firebaseio.com/push_tokens/' + urllib.quote(uid) + '.json'
    print url
    d = json.loads(urllib2.urlopen(url).read())
    return d.values() if isinstance(d, dict) else []

class PushHandler(webapp2.RequestHandler):
    def post(self):
        body = json.loads(self.request.body)
        success = PushService.send_pushes(map(Push, body['pushes']))
        self.response.write(json.dumps({"success": success}))

class Push(object):
    def __init__(self, j, extra=None):
        self.text = j.get('text', '')
        self.link = j.get('link')
        self.extra = extra if extra else {}
        self.recipients = tokens_for_user_id(j.get('recipient'))
        self.custom = {}
        if self.link:
            self.custom['link'] = self.link

class PushService(object):
    def __init__(self, name):
        self.name = name
    
    def send_applicable_pushes(self, pushes):
        pass
    
    @classmethod
    def send_pushes(cls, pushes):
        for service in PUSH_SERVICES:
            service.send_applicable_pushes(pushes)
        return True

class ApplePushService(PushService):
    def send_applicable_pushes(self, pushes):
        payloads_and_tokens = [] # [(payload, token)]
        for push in pushes:
            for recip in push.recipients:
                if '.' in recip:
                    token, service = recip.split('.', 1)
                    if service == self.name:
                        pl = Payload(alert=push.text, sound='default', badge=1, custom=push.custom)
                        payloads_and_tokens.append((pl, token))
        if len(payloads_and_tokens):
            prefix = 'dev' if self.is_sandbox() else 'prod'
            apns = APNs(use_sandbox=self.is_sandbox(), cert_file=prefix + '-cert.pem', key_file=prefix + '-key.pem')
            frame = Frame()
            identifier = 1
            expiry = time.time() + 3600
            priority = 10
            for payload, token in payloads_and_tokens:
                frame.add_item(token, payload, identifier, expiry, priority)
            apns.gateway_server.send_notification_multiple(frame)
    
    def is_sandbox(self):
        return False

class ApplePushSandboxService(ApplePushService):
    def is_sandbox(self):
        return True

PUSH_SERVICES = [ApplePushService('apple'), ApplePushSandboxService('apple-sandbox')]

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/push', PushHandler)
], debug=True)
