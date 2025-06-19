from datetime import datetime
from jinja2 import pass_context

@pass_context
def datetimeformat(context, value, format='%d/%m/%Y - %H:%M:%S'):
    if not value:
        return '-'
    try:
        # Tenta converter de string para datetime
        if isinstance(value, str):
            # Suporta formatos ISO e já formatados
            try:
                dt = datetime.fromisoformat(value.replace('Z', '+00:00'))
            except Exception:
                dt = datetime.strptime(value, '%d/%m/%Y - %H:%M:%S')
        else:
            dt = value
        return dt.strftime(format)
    except Exception:
        return value
