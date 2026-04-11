from rest_framework import serializers

from .models import Material


class MaterialSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.username", read_only=True)
    subject_name = serializers.CharField(source="subject.name", read_only=True)

    class Meta:
        model = Material
        fields = [
            "id",
            "title",
            "description",
            "file",
            "owner",
            "subject",
            "subject_name",
            "owner_name",
            "created_at",
        ]
        read_only_fields = ["id", "owner", "owner_name", "created_at"]
