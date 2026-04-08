from .views import SubjectListCreateView, SubjectDetailView, SubjectEnrollView
from django.urls import path

urlpatterns = [
    path('subjects/', SubjectListCreateView.as_view(), name='subject-list-create'),
    path('subjects/<int:pk>/', SubjectDetailView.as_view(), name='subject-detail'),
    path('subjects/<int:pk>/enroll/', SubjectEnrollView.as_view(), name='subject-enroll'),
]