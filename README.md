
# TenderGo

## Kredencijali za testiranje

| Kontekst         | Korisničko ime       | Lozinka   |
|------------------|----------------------|-----------|
| Desktop          | `admin@tendergo.com` | Admin123! |
| Mobile           | `amina@tendergo.com` | User123!  |


 > **Napomena:** U bazi postoji više predefinisanih mobilnih korisnika. Za potpuno testiranje svih funkcionalnosti aplikacije preporučuje se korištenje korisničkog računa amina@tendergo.com, jer su za njega seedani svi podaci potrebni za demonstraciju sistema (tenderi, ponude, notifikacije, ocjene i ostali testni podaci). Za korisničke račune marko@tendergo.com i mujo@tendergo.com nisu seedani svi podaci, te se oni mogu koristiti samo za djelimično testiranje pojedinih funkcionalnosti.
> Seeder se automatski izvršava pri pokretanju aplikacije.

## Preduslovi

- Docker Desktop
- Android emulator ili fizički Android uređaj (za testiranje mobilne aplikacije)

## Pokretanje projekta

1. **Preuzimanje projekta**

   Preuzmite najnoviju verziju projekta sa GitHub Releases stranice i raspakujte arhivu.
   
2. **Priprema okruženja**

   Raspakujte `.env` datoteku u root direktorijum projekta (`TenderGo/`).

3. **Pokretanje Docker Desktop-a**

   Provjerite da je Docker Desktop pokrenut prije nastavka.   

4. **Pokretanje backend servisa**

   U root direktorijumu projekta izvršite naredbu:

   ```bash
   docker compose up --build

5. **Pokretanje desktop aplikacije**
   Pokrenite priloženu desktop aplikaciju (TenderGoDesktop.exe).
   
6. **Pokretanje mobilne aplikacije**
Instalirajte priloženu TenderGo.apk datoteku na Android uređaj ili emulator i pokrenite aplikaciju
