from .views import (
    SubjectListCreateView,
    SubjectDetailView,
    SubjectEnrollView,
    SubjectEnrolledStudentsView,
    SubjectRemoveStudentView,
)
from django.urls import path

urlpatterns = [
    path('subjects/', SubjectListCreateView.as_view(), name='subject-list-create'),
    path('subjects/<int:pk>/', SubjectDetailView.as_view(), name='subject-detail'),
    path('subjects/<int:pk>/enroll/', SubjectEnrollView.as_view(), name='subject-enroll'),
    path('subjects/<int:pk>/students/', SubjectEnrolledStudentsView.as_view(), name='subject-enrolled-students'),
    path('subjects/<int:pk>/students/<int:user_id>/', SubjectRemoveStudentView.as_view(), name='subject-remove-student'),
]