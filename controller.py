from exceptable.exceptable import Except

base = Except(InternalError, {
    'PermissionError': PermissionError,
    'Exception': Exception,
    'NotFoundException': NotFoundError,
})
