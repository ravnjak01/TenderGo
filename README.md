Desktop/mobile:
korisničko ime admin@tendergo.com      password:Admin123!
        mujo@tendergo.com              password:User123!
        suljo@tendergo.com             password:User123!
        amina@tendergo.com             password:User123!
        
      


Pokretanje aplikacije:
Prije pokretanja aplikacije potrebno je instalirati sljedeće alate:

Docker Desktop
Flutter SDK
.NET 8 SDK
Visual Studio 2022 ili VS Code
Android emulator ili fizički uređaj za testiranje mobilne aplikacije

Nakon instalacije potrebno je klonirati repozitorij:

git clone <repo-link>
cd TenderGo

U root direktoriju projekta potrebno je kreirati .env fajl sa konfiguracijskim podacima.

Primjer .env fajla:
Jwt__Key=TVOJ_TAJNI_JWT_KLJUC_MINIMALNO_32_KARAKTERA
Jwt__Issuer=TenderGo.Api
Jwt__Audience=TenderGo.ApiUsers
Jwt__ExpiresInMinutes=60

SA_PASSWORD=TVAJA_JAKA_SA_LOZINKA
DB_NAME=TenderGo
DB_CONNECTION=Server=tendergo-sql;Database=TenderGo;User Id=sa;Password=TVAJA_JAKA_SA_LOZINKA;TrustServerCertificate=True;

RABBITMQ_USER=tendergo_user
RABBITMQ_PASS=TVOJA_RABBITMQ_LOZINKA
ConnectionStrings__RabbitMQ=host=tendergo-rabbitmq;username=tendergo_user;password=TVOJA_RABBITMQ_LOZINKA;timeout=30

FRONTEND_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:5000,http://127.0.0.1:3000

EmailSettings__From=tvoj.email@gmail.com
EmailSettings__SmtpServer=smtp.gmail.com
EmailSettings__Port=587
EmailSettings__Username=tvoj.email@gmail.com
EmailSettings__Password=TVOJ_GMAIL_APP_PASSWORD_OD_16_SLOVA

Nakon toga potrebno je pokrenuti Docker kontejnere iz root direktorija projekta:

docker compose up --build

Ova komanda pokreće SQL Server bazu, RabbitMQ, ASP.NET Web API i recommender subscriber servis.

Backend aplikacija će biti dostupna na adresi:

http://localhost:8080

Swagger dokumentacija će biti dostupna na:

http://localhost:8080/swagger

RabbitMQ management panel dostupan je na:

http://localhost:15672

Default kredencijali za RabbitMQ su:

username: guest
password: guest

Za pokretanje Flutter aplikacije potrebno je otvoriti Flutter projekat:

Mobilna aplikacija:

cd UI/tendergo_mobile

Desktop aplikacija:

cd UI/tendergo_desktop

Zatim instalirati dependencies:

flutter pub get

Pokretanje mobilne aplikacije:

flutter run

Pokretanje desktop aplikacije:

flutter run -d windows

Aplikacija prilikom pokretanja automatski seed-a testne podatke uključujući administratore, korisnike, tendere, kategorije i lokacije.

Testni admin nalog:

Email: admin@tendergo.com
Password: Admin123!

Testni korisnički nalog:

Email: user@tendergo.com
Password: User123!

Napomene:

Docker Desktop mora biti pokrenut prije izvršavanja docker compose up.
Seeder se automatski izvršava pri pokretanju aplikacije.
Za testiranje na fizičkom mobilnom uređaju potrebno je postaviti lokalnu IP adresu backend servera u Flutter aplikaciji.
Nakon izmjena backend koda potrebno je ponovo pokrenuti:
docker compose up --build
