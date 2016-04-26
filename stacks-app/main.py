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

BATCH_REST_KEY = '3a4af5d74cca3752a5f479484be5c75b'
BATCH_APP_KEY = 'DEV571EFB103BD2CD4462B18AE8C44'

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

class PushHandler(webapp2.RequestHandler):
    def post(self):
        success = True
        body = json.loads(self.request.body)
        for push in body['pushes']:            
            text = push.get('text')
            recipient = push.get('recipient')
            link = push.get('link')
            payload = {
                "group_id": "notification",
                "recipients": {
                    "custom_ids": [recipient]
                },
                "message": {
                    "body": text
                },
                "custom_payload": "{}"
            }
            if link:
                payload['deeplink'] = link
            
            post_body = json.dumps(payload)
            print post_body
            headers = {
                "X-Authorization": BATCH_REST_KEY,
                "Content-Type": "application/json"
            }
            req = urllib2.Request("https://api.batch.com/1.0/{0}/transactional/send".format(BATCH_APP_KEY), post_body, headers)
            try:
                f = urllib2.urlopen(req)
                response = f.read()
                f.close()
            except urllib2.HTTPError as e:
                print "Error delivering push:", e
                print e.read()
                success = False
        self.response.write(json.dumps({"success": success}))
            

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/push', PushHandler)
], debug=True)
