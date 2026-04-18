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
    # Accept uploads under the existing request key `file`
    file = serializers.FileField(write_only=True, required=False)
    file_name = serializers.CharField(read_only=True)

    class Meta:
        model = Submission
        fields = [
            "id",
            "assignment",
            "student",
            "student_name",
            "file",
            "file_name",
            "comments",
            "submitted_at",
            "grade",
        ]

        # assignment & student are set in the view from the URL + token
        read_only_fields = [
            "id",
            "assignment",
            "student",
            "student_name",
            "submitted_at",
            "grade",
            "file_name",
        ]

    def create(self, validated_data):
        uploaded = validated_data.pop("file", None)
        if uploaded is None:
            raise serializers.ValidationError({"file": ["This field is required."]})

        submission = Submission(**validated_data)
        submission.file_blob = uploaded.read()
        submission.file_name = getattr(uploaded, "name", "") or ""
        submission.file_content_type = getattr(uploaded, "content_type", "") or ""
        submission.save()
        return submission

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # For Flutter compatibility, return a URL string under the key `file`
        request = self.context.get("request")
        path = f"/api/assignments/submissions/{instance.id}/file/"
        data["file"] = request.build_absolute_uri(path) if request else path
        return data
