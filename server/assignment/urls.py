from django.urls import path
from .views import (
    AssignmentListCreateView,
    AssignmentDetailView,
    SubmissionListCreateView,
    SubmissionDetailView,
    SubmissionFileDownloadView,
)

urlpatterns = [
    path('assignments/', AssignmentListCreateView.as_view(), name='assignment-list-create'),
    path('assignments/<int:pk>/', AssignmentDetailView.as_view(), name='assignment-detail'),
    path('assignments/<int:pk>/submissions/', SubmissionListCreateView.as_view(), name='submission-list-create'),
    path('assignments/submissions/<int:pk>/', SubmissionDetailView.as_view(), name='submission-detail'),
    path('assignments/submissions/<int:pk>/file/', SubmissionFileDownloadView.as_view(), name='submission-file-download'),
]
