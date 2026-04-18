from django.db import models
from django.conf import settings


# Create your models here.
class Assignment(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    due_date = models.DateTimeField()
    attachment = models.FileField(upload_to="assignments/%Y/%m/%d/", null=True, blank=True)
    owner = models.ForeignKey("authentication.User", on_delete=models.CASCADE, related_name="assignments")
    subject = models.ForeignKey(
        "subject.Subject",
        on_delete=models.CASCADE,
        related_name="assignments",
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class Submission(models.Model):
    assignment = models.ForeignKey(Assignment, on_delete=models.CASCADE, related_name="submissions")
    student = models.ForeignKey("authentication.User", on_delete=models.CASCADE, related_name="submissions")
    file_blob = models.BinaryField(null=True, blank=True)
    file_name = models.CharField(max_length=255, blank=True, default="")
    file_content_type = models.CharField(max_length=127, blank=True, default="")
    comments = models.TextField(blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    grade = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return f"Submission {self.id} for {self.assignment.title} by {self.student.username}"
