from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from .models import User, PasswordEntry, SecureNote, CreditCard, IdentityCard, EncryptionKey, Log

@receiver(post_save, sender=User)
@receiver(post_save, sender=PasswordEntry)
@receiver(post_save, sender=SecureNote)
@receiver(post_save, sender=CreditCard)
@receiver(post_save, sender=IdentityCard)
@receiver(post_save, sender=EncryptionKey)
def log_save(sender, instance, created, **kwargs):
    action = 'created' if created else 'updated'
    Log.objects.create(
        user=instance.user if hasattr(instance, 'user') else None,
        action=f'{instance.__class__.__name__} {action}',
        timestamp=timezone.now()
    )

@receiver(post_delete, sender=User)
@receiver(post_delete, sender=PasswordEntry)
@receiver(post_delete, sender=SecureNote)
@receiver(post_delete, sender=CreditCard)
@receiver(post_delete, sender=IdentityCard)
@receiver(post_delete, sender=EncryptionKey)
def log_delete(sender, instance, **kwargs):
    Log.objects.create(
        user=instance.user if hasattr(instance, 'user') else None,
        action=f'{instance.__class__.__name__} deleted',
        timestamp=timezone.now()
    )
