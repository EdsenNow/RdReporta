namespace RdReporta.Domain.Enums;

public enum ReputationLevel
{
    Ciudadano = 1,
    Colaborador = 2,
    ColaboradorConfiable = 3
}

public enum PostStatus
{
    Active = 1,
    Resolved = 2,
    Hidden = 3,
    Archived = 4
}

public enum ReactionType
{
    MeInteresa = 1,
    Importante = 2,
    Impactante = 3,
    EstoyAqui = 4,
    MeGusta = 5,
    Corazon = 6,
    ConLagrima = 7,
    Enojo = 8,
    Sorpresa = 9
}

public enum ModerationReason
{
    InformacionFalsa = 1,
    Spam = 2,
    Acoso = 3,
    DatosPersonales = 4,
    ContenidoViolento = 5,
    UbicacionIncorrecta = 6,
    PublicacionDuplicada = 7,
    Otro = 8
}

public enum ModerationStatus
{
    Pending = 1,
    Reviewed = 2,
    Dismissed = 3,
    ActionTaken = 4
}
