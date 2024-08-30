from django.utils.deprecation import MiddlewareMixin
from django.utils import timezone
from .models import Log

class LoggingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        if request.user.is_authenticated:
            Log.objects.create(
                user=request.user,
                action=f'{request.method} {request.get_full_path()}',
                timestamp=timezone.now()
            )

    def process_response(self, request, response):
        return response

    def process_exception(self, request, exception):
        return None
