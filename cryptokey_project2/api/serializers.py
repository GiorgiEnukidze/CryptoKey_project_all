# api/serializers.py
from rest_framework import serializers
from .models import PasswordEntry, SecureNote, CreditCard, IdentityCard, EncryptionKey, User, PasswordShare,Log
from cryptography.fernet import InvalidToken
from api.models import PasswordShare, decrypt_data

class PasswordEntrySerializer(serializers.ModelSerializer):
    password = serializers.SerializerMethodField()

    class Meta:
        model = PasswordEntry
        fields = ['id', 'user', 'site_name', 'site_url', 'username', 'password', 'created_at', 'updated_at']

    def get_password(self, obj):
        return obj.get_decrypted_password()

class SecureNoteSerializer(serializers.ModelSerializer):
    content = serializers.SerializerMethodField()  # Ajoutez cela

    class Meta:
        model = SecureNote
        fields = ['id', 'user', 'title', 'content', 'created_at', 'updated_at']

    def get_content(self, obj):
        return decrypt_data(obj.encrypted_content)


class CardSerializer(serializers.ModelSerializer):
    class Meta:
        model = CreditCard
        fields = ['id', 'user', 'encrypted_card_number', 'expiry_date', 'cvv', 'cardholder_name', 'created_at', 'updated_at']
    def get_card_number(self, obj):
        return decrypt_data(obj.encrypted_card_number)

class IdentitySerializer(serializers.ModelSerializer):
    class Meta:
        model = IdentityCard
        fields = ['id', 'user', 'name', 'surname', 'nationality', 'encrypted_id_number', 'date_of_issue', 'expiry_date', 'date_of_birth', 'created_at', 'updated_at']
    def get_id_number(self, obj):
        return decrypt_data(obj.encrypted_id_number)


class EncryptionKeySerializer(serializers.ModelSerializer):
    class Meta:
        model = EncryptionKey
        fields = ['id', 'user', 'titles', 'encrypted_key', 'created_at', 'updated_at']
    def get_key(self, obj):
        return decrypt_data(obj.encrypted_key)


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)  

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'password']  

class PasswordShareSerializer(serializers.ModelSerializer):
    site_name = serializers.CharField(source='password_entry.site_name')
    username = serializers.CharField(source='password_entry.username')
    site_url = serializers.CharField(source='password_entry.site_url')
    password = serializers.SerializerMethodField()

    class Meta:
        model = PasswordShare
        fields = ['id', 'site_name', 'username', 'site_url', 'password', 'expiration_date', 'created_at', 'updated_at']

    def get_password(self, obj):
        try:
            return decrypt_data(obj.password_entry.password)
        except InvalidToken:
            return "[Decryption Error]"




class PasswordImportSerializer(serializers.ModelSerializer):
    class Meta:
        model = PasswordEntry
        fields = ['site_name', 'site_url', 'username', 'password', 'created_at', 'updated_at']

class PasswordExportSerializer(serializers.ModelSerializer):
    class Meta:
        model = PasswordEntry
        fields = ['site_name', 'site_url', 'username', 'password', 'created_at', 'updated_at']


class LogSerializer(serializers.ModelSerializer):
    class Meta:
        model = Log
        fields = '__all__'


class TwoFactorSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    code = serializers.CharField(max_length=6)