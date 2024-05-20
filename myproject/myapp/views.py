from django.shortcuts import render

from django.core.cache import cache
from django.http import HttpResponse
import time

def my_view(request):
    if 'my_key' in cache:
        value = cache.get('my_key')
    else:
        value = str(time.time())
        cache.set('my_key', value, timeout=30)
    return HttpResponse(f"Value: {value}")
