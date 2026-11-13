// Optional deep-link handling. Backend permissions still decide whether the item is readable.
If(!deepLinkHandled,
    Set(deepLinkHandled,true);
    If(IsMatch(Param("requestId"),"\d+"),
        Refresh(GTASRequestsV2);
        Set(r,LookUp(GTASRequestsV2,ID=Value(Param("requestId"))));
        If(IsBlank(r),
            Set(message,"The request is unavailable or you do not have access."),
            Navigate(Request)
        )
    )
)
