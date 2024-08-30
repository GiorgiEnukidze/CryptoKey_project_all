# show_urls.py
from django.urls import get_resolver

def list_urls():
    urls = get_resolver().url_patterns
    for url in urls:
        print(url.pattern)

if __name__ == "__main__":
    list_urls()
