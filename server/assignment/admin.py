from django.contrib import admin
from .models import Assignment, Submission


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
	list_display = ("id", "title", "owner", "due_date", "created_at")
	search_fields = ("title", "owner__username")


@admin.register(Submission)
class SubmissionAdmin(admin.ModelAdmin):
	list_display = ("id", "assignment", "student", "submitted_at")
	search_fields = ("assignment__title", "student__username")
