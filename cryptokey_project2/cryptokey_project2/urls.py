# cryptokey_project2/urls.py

from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('', RedirectView.as_view(url='/api/')),  # Redirige l'URL racine vers l'API
    path('metrics/', include('django_prometheus.urls')),  # Expose les métriques à /metric
]
