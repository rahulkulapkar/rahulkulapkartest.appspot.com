<%@page import="java.util.TimeZone"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<%@ page import="java.util.List"%>
<%@ page import="com.google.appengine.api.users.User"%>
<%@ page import="com.google.appengine.api.users.UserService"%>
<%@ page import="com.google.appengine.api.users.UserServiceFactory"%>
<%@ page
	import="com.google.appengine.api.datastore.DatastoreServiceFactory"%>
<%@ page import="com.google.appengine.api.datastore.DatastoreService"%>
<%@ page import="com.google.appengine.api.datastore.Query"%>
<%@ page import="com.google.appengine.api.datastore.Entity"%>
<%@ page import="com.google.appengine.api.datastore.FetchOptions"%>
<%@ page import="com.google.appengine.api.datastore.Key"%>
<%@ page import="com.google.appengine.api.datastore.KeyFactory"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<html>
<head>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
</head>

<body>

	<%
    String guestbookName = request.getParameter("guestbookName");
	SimpleDateFormat sdf = new SimpleDateFormat("EEE d MMM, yyyy h:mm a");
	sdf.setTimeZone(TimeZone.getTimeZone("GMT+530"));
    if (guestbookName == null) {
        guestbookName = "default";
    }
    pageContext.setAttribute("guestbookName", guestbookName);
    UserService userService = UserServiceFactory.getUserService();
    User user = userService.getCurrentUser();
    if (user != null) {
      pageContext.setAttribute("user", user);
%>
	<p>
		Hello, <%= user.getNickname() %> (You can <a
			href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign
			out</a>.)
	</p>
	<%
    } else {
%>
	<p>
		Hello! <a
			href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign
			in</a> to include your name with greetings you post.
	</p>
	<%
    }
%>

	<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key guestbookKey = KeyFactory.createKey("Guestbook", guestbookName);
    // Run an ancestor query to ensure we see the most up-to-date
    // view of the Greetings belonging to the selected Guestbook.
    Query query = new Query("Greeting", guestbookKey).addSort("date", Query.SortDirection.DESCENDING);
    List<Entity> greetings = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(5));
    if (greetings.isEmpty()) {
        %>
	<p>Guestbook '<%= guestbookName %>' has no messages.</p>
	<%
    } else {
        %>
	<p>Messages in Guestbook '<%= guestbookName %>'.</p>
	<%
        for (Entity greeting : greetings) {
            pageContext.setAttribute("greeting_content",
                                     greeting.getProperty("content"));
            if (greeting.getProperty("user") == null) {
                %>
	<p>An anonymous person wrote on <%= sdf.format(((Date)greeting.getProperty("date"))) %>:</p>
	<%
            } else {
                pageContext.setAttribute("greeting_user",
                                         greeting.getProperty("user"));
                %>
	<p>
		<b><%= ((User)greeting.getProperty("user")).getNickname() %></b> wrote on <%= sdf.format(((Date)greeting.getProperty("date"))) %>:
	</p>
	<%
            }
            %>
	<blockquote><b><%= greeting.getProperty("subject") %></b></blockquote>
	<blockquote><%= greeting.getProperty("content") %></blockquote>
	<%
        }
    }
%>

	<form action="/sign" method="post">
		<div>
			Subject: <input type="text" name="subject" maxlength="20" />
		</div>
		<div>
			<textarea name="content" rows="3" cols="80"></textarea>
		</div>
		<div>
			<input type="submit" value="Post Greeting" />
		</div>
		<input type="hidden" name="guestbookName"
			value="<%= guestbookName %>" />
	</form>

</body>
</html>