from .models import Assignment, Submission
from rest_framework import serializers


class AssignmentSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.username", read_only=True)
    subject_name = serializers.CharField(source="subject.name", read_only=True)

    class Meta:
        model = Assignment
        fields = [
            "id",
            "title",
            "description",
            "due_date",
            "attachment",
            "owner",
            "subject",
            "subject_name",
            "owner_name",
            "created_at",
        ]
        read_only_fields = ["id", "owner", "owner_name", "created_at"]


class SubmissionSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source="student.username", read_only=True)

    class Meta:
        model = Submission
        fields = [
            "id",
            "assignment",
            "student",
            "student_name",
            "file",
            "comments",
            "submitted_at",
            "grade",
        ]
        read_only_fields = ["id", "student", "student_name", "submitted_at", "grade"]
