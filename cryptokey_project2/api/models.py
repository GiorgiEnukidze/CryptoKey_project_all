#api/models
from datetime import timezone
from venv import logger
from django.utils import timezone
from django.db import models
from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password
from cryptography.fernet import Fernet, InvalidToken

class Log(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=255)
    timestamp = models.DateTimeField()

    def __str__(self):
        return f'{self.user.username if self.user else "Unknown"} - {self.action} at {self.timestamp}'

# Clé secrète pour le chiffrement
SECRET_KEY = b'vO1IpBzkzAjN9It1dOh8h0d9g1T9R9cYGKwBdpxB21g='
cipher_suite = Fernet(SECRET_KEY)

# Fonction pour chiffrer les données
def encrypt_data(data):
    return cipher_suite.encrypt(data.encode()).decode()

# Fonction pour déchiffrer les données
def decrypt_data(encrypted_data):
    return cipher_suite.decrypt(encrypted_data.encode()).decode()

class PasswordEntry(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    site_name = models.CharField(max_length=255)
    site_url = models.URLField()
    username = models.CharField(max_length=150)
    password = models.CharField(max_length=256)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        try:
            decrypt_data(self.password)
        except InvalidToken:
            self.password = encrypt_data(self.password)
        super().save(*args, **kwargs)

    def get_decrypted_password(self):
        try:
            return decrypt_data(self.password)
        except InvalidToken as e:
            logger.error(f"Decryption failed for password: {self.password} with error {str(e)}")
            return "[Invalid Token]"
        
    def __str__(self):
        return f"{self.site_name}: {self.username}"


        

class SecureNote(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    encrypted_content = models.TextField()  # Champ pour stocker le contenu chiffré de la note
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if self.encrypted_content:
            self.encrypted_content = encrypt_data(self.encrypted_content)  # Chiffrer le contenu avant de l'enregistrer
        super().save(*args, **kwargs)

    def get_content(self):
        return decrypt_data(self.encrypted_content)  # Déchiffrer et renvoyer le contenu de la note

class CreditCard(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    encrypted_card_number = models.CharField(max_length=256)  # Champ pour stocker le numéro de carte chiffré
    expiry_date = models.DateField()
    cvv = models.CharField(max_length=4)
    cardholder_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.cardholder_name

    def save(self, *args, **kwargs):
        if self.encrypted_card_number:
            self.encrypted_card_number = encrypt_data(self.encrypted_card_number)  # Chiffrer le numéro de carte avant de l'enregistrer
        super().save(*args, **kwargs)

    def get_card_number(self):
        return decrypt_data(self.encrypted_card_number)  # Déchiffrer et renvoyer le numéro de carte

class IdentityCard(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    encrypted_id_number = models.CharField(max_length=256)  # Champ pour stocker le numéro d'identité chiffré
    name = models.CharField(max_length=255, default="Unknown")
    surname = models.CharField(max_length=255, default="Unknown")
    nationality = models.CharField(max_length=255, default="Unknown")
    date_of_issue = models.DateTimeField(default=timezone.now)
    expiry_date = models.DateTimeField(default=timezone.now)
    date_of_birth = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if self.encrypted_id_number:
            self.encrypted_id_number = encrypt_data(self.encrypted_id_number)  # Chiffrer le numéro d'identité avant de l'enregistrer
        super().save(*args, **kwargs)

    def get_id_number(self):
        return decrypt_data(self.encrypted_id_number)  # Déchiffrer et renvoyer le numéro d'identité

class EncryptionKey(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    titles = models.TextField(max_length=255, default="Unknown")
    encrypted_key = models.TextField()  # Champ pour stocker la clé de chiffrement chiffrée
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.titles}"

    def save(self, *args, **kwargs):
        if self.encrypted_key:
            self.encrypted_key = encrypt_data(self.encrypted_key)  # Chiffrer la clé avant de l'enregistrer
        super().save(*args, **kwargs)

    def get_key(self):
        return decrypt_data(self.encrypted_key)  # Déchiffrer et renvoyer la clé de chiffrement

    
class PasswordShare(models.Model):
    password_entry = models.ForeignKey('PasswordEntry', on_delete=models.CASCADE)
    shared_with_user = models.ForeignKey(User, related_name='shared_passwords', on_delete=models.CASCADE)
    shared_by_user = models.ForeignKey(User, related_name='shared_by_user', on_delete=models.CASCADE)
    expiration_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['password_entry', 'shared_with_user', 'shared_by_user'], name='unique_password_share')
        ]

    def is_expired(self):
        if self.expiration_date:
            return timezone.now() > self.expiration_date
        return False

    def __str__(self):
        return f"{self.password_entry.site_name} shared with {self.shared_with_user.username}"


