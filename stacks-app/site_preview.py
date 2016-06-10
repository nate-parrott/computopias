import webapp2
import bs4
import json
import urllib2
import util

def first(items):
    for x in items:
        if x is not None:
            return x
    return None

class Handler(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'application/json'
        resp = {
            "url": self.request.get('url')
        }
        html = util.url_fetch(self.request.get('url'))
        if html:        
            def text(node):
                return node.text if node else None
        
            def content(node):
                return node['content'] if node and node.has_attr('content') else None
        
            def src(node):
                return node['src'] if node and node.has_attr('src') else None
            
            soup = bs4.BeautifulSoup(html, 'lxml')
            resp['title'] = first([
                content(soup.find('meta', {'property': 'og:title'})),
                text(soup.find('title'))
            ])
            resp['description'] = first([
                content(soup.find('meta', {'property': 'og:description'})),
                content(soup.find('meta', {'name': 'description'}))
            ])
            resp['image'] = first([
                content(soup.find('meta', {'name': 'og:image'})),
                src(soup.find('img'))
            ])
            url = content(soup.find('meta', {"property": "og:url"}))
            if url: resp['url'] = url
        self.response.write(json.dumps(resp))
