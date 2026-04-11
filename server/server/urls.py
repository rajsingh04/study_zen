
from django.contrib import admin
from django.urls import path, include
from authentication import urls as authUrls
from subject import urls as subjectUrls
from assignment import urls as assignmentUrls
from material import urls as materialUrls
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include(authUrls.urlpatterns)),
    path('api/', include(subjectUrls)),  # /api/subjects/... endpoints
    path('api/', include(assignmentUrls)),  # /api/assignments/... endpoints
    path('api/', include(materialUrls)),  # /api/materials/... endpoints
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
