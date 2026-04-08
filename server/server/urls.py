
from django.contrib import admin
from django.urls import path, include
from authentication import urls as authUrls
from subject import urls as subjectUrls

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include(authUrls.urlpatterns)),
    path('api/', include(subjectUrls)),  # /api/subjects/... endpoints
]
