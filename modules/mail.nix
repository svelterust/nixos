{pkgs, ... }: let
  createPurelymailAccount = {
    name,
    email,
    encryptedKey,
  }: let
    keyFile = pkgs.writeText "${email}.gpg" encryptedKey;
  in {
    address = "${email}.gpg";
    gpg = {
      key = "EEBBE41FE57C0E911CA2E0C7323E010A4776C0DA";
      signByDefault = true;
    };
    imap.host = "imap.purelymail.com";
    mbsync = {
      enable = true;
      create = "maildir";
    };
    realName = name;
    msmtp.enable = true;
    notmuch.enable = true;
    primary = true;
    passwordCommand = ''gpg --batch --no-tty --decrypt < ${keyFile}'';
    smtp.host = "smtp.purelymail.com";
    userName = email;
  };
in
  {
    programs.mbsync.enable = true;
    programs.msmtp.enable = true;
    programs.notmuch = {
      enable = true;
      hooks = {
        preNew = "mbsync --all";
      };
    };
    
    accounts.email = {
      accounts.oddharald = createPurelymailAccount {
        name = "Odd-Harald";
        email = "oddharald@verdivekst.no";
        encryptedKey = ''
-----BEGIN PGP MESSAGE-----

hF4Dhyty0QE4VIQSAQdAL07erMDFSyms4s4LL0KjSR7EWHoiJhJcP1icSmybqScw
uju1JV1pGFDoq7LwXJh9HugJkusJ2sWjagYsqcStreZy3MzlbsVtAkQJHXrX/vFM
1FIBCQIQc/jpnPNm+aUnKTow3nb5qTsi3LUHHZik6BAWntDeulsXNH9pqnbRQTEm
QVLFMP2WG5vyqo/h91v6VgcgPL31Cmo4PtYnSjwGpC8pYDHV
=obM4
-----END PGP MESSAGE-----
'';
      };
    };
  }
