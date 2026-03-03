
from django.contrib import admin
from django.urls import path
from authentication import urls as authUrls
from django.urls import include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include(authUrls.urlpatterns)),
]
